
WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 10 AND 20 
        AND p.p_retailprice IS NOT NULL
),
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey, 
        SUM(ps.ps_availqty) AS total_avail_qty,
        MAX(s.s_acctbal) AS max_acct_bal
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey
),
ExtremeOrders AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_orderkey) AS line_item_count,
        AVG(l.l_discount) AS avg_discount
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus IN ('O', 'F') 
        AND l.l_shipdate > DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
TopNationSuppliers AS (
    SELECT 
        n.n_name, 
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    WHERE 
        s.s_acctbal > (
            SELECT 
                AVG(s2.s_acctbal)
            FROM 
                supplier s2
            WHERE 
                s2.s_acctbal IS NOT NULL
        )
    GROUP BY 
        n.n_name
)
SELECT 
    rp.p_name, 
    ra.total_avail_qty, 
    eo.total_order_value,
    tn.supplier_count,
    CASE 
        WHEN tn.supplier_count IS NULL THEN 'No Suppliers'
        WHEN tn.supplier_count > 10 THEN 'Many Suppliers'
        ELSE 'Few Suppliers'
    END AS supplier_status
FROM 
    RankedParts rp
LEFT JOIN 
    SupplierAvailability ra ON rp.p_partkey = ra.ps_partkey
FULL OUTER JOIN 
    ExtremeOrders eo ON eo.o_orderkey = (SELECT MIN(o_orderkey) FROM ExtremeOrders)
JOIN 
    TopNationSuppliers tn ON tn.n_name LIKE CONCAT('%', SUBSTRING(rp.p_name, 1, 3), '%')
WHERE 
    rp.price_rank <= 5 
    AND ra.total_avail_qty IS NOT NULL
ORDER BY 
    rp.p_retailprice DESC, 
    tn.supplier_count DESC;
