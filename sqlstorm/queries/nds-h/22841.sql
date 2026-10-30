
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank_per_brand
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(ps.ps_partkey) AS supplier_part_count,
        SUM(ps.ps_availqty) AS total_available_qty
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        CUME_DIST() OVER (ORDER BY o.o_totalprice DESC) AS price_distribution
    FROM 
        orders o
    WHERE 
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
),
FlaggedLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_discount,
        l.l_tax,
        l.l_returnflag,
        l.l_linestatus,
        CASE 
            WHEN l.l_returnflag = 'R' THEN 'Returned'
            ELSE 'Not Returned'
        END AS return_status
    FROM 
        lineitem l
),
FilteredNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(s.s_acctbal) AS total_acct_balance
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    WHERE 
        n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name LIKE '%North%')
    GROUP BY 
        n.n_nationkey, n.n_name
)

SELECT 
    rp.p_brand,
    rp.p_name,
    rp.p_retailprice,
    ss.supplier_part_count,
    ss.total_available_qty,
    COUNT(hvo.o_orderkey) AS high_value_order_count,
    AVG(fli.l_quantity) AS avg_lineitem_quantity,
    fn.total_acct_balance
FROM 
    RankedParts rp
LEFT JOIN 
    SupplierStats ss ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = ss.s_suppkey)
LEFT JOIN 
    HighValueOrders hvo ON hvo.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = rp.p_partkey)
LEFT JOIN 
    FlaggedLineItems fli ON fli.l_orderkey = hvo.o_orderkey
JOIN 
    FilteredNations fn ON fn.n_nationkey = (SELECT MIN(n.n_nationkey) FROM nation n WHERE n.n_name = 'USA')
WHERE 
    rp.rank_per_brand <= 3
GROUP BY 
    rp.p_brand, rp.p_name, rp.p_retailprice, ss.supplier_part_count, ss.total_available_qty, fn.total_acct_balance
HAVING 
    SUM(ss.total_available_qty) IS NOT NULL
ORDER BY 
    rp.p_brand, rp.p_retailprice DESC;
