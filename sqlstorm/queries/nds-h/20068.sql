WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('O', 'F') 
        AND o.o_orderdate > (cast('1998-10-01' as date) - INTERVAL '1 year')
),
SupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        s.s_nationkey,
        s.s_acctbal,
        SUM(ps.ps_availqty) AS total_avail_qty,
        COUNT(DISTINCT s.s_suppkey) AS unique_suppliers
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) 
    GROUP BY 
        ps.ps_partkey, s.s_nationkey, s.s_acctbal
),
CustomerSegments AS (
    SELECT 
        c.c_custkey,
        c.c_mktsegment,
        COALESCE(SUM(o.o_totalprice), 0) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_mktsegment
),
TotalLineItems AS (
    SELECT 
        l.l_partkey,
        COUNT(*) AS total_lines,
        SUM(l.l_extendedprice) AS total_price,
        AVG(l.l_discount) AS avg_discount
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N'
        AND l.l_shipdate BETWEEN '1997-01-01' AND cast('1998-10-01' as date)
    GROUP BY 
        l.l_partkey
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_type,
    p.p_size,
    p.p_retailprice,
    COALESCE(td.total_lines, 0) AS total_lines,
    COALESCE(td.total_price, 0) AS total_price,
    COALESCE(td.avg_discount, 0) AS avg_discount,
    cs.total_spent,
    nations_col.n_name AS supplier_nation,
    io.order_rank
FROM 
    part p
LEFT JOIN 
    TotalLineItems td ON p.p_partkey = td.l_partkey
LEFT JOIN 
    SupplierDetails sd ON p.p_partkey = sd.ps_partkey
LEFT JOIN 
    CustomerSegments cs ON cs.c_mktsegment LIKE '%' || p.p_type || '%'
LEFT JOIN 
    nation nations_col ON sd.s_nationkey = nations_col.n_nationkey
LEFT JOIN 
    RankedOrders io ON io.o_orderkey = (SELECT MIN(o_orderkey) FROM orders WHERE o_orderdate < cast('1998-10-01' as date))
WHERE 
    (p.p_retailprice BETWEEN 10 AND 100 OR p.p_type = 'Standard')
    AND (io.order_rank IS NULL OR io.order_rank <= 5)
ORDER BY 
    p.p_brand, 
    p.p_size DESC, 
    total_price DESC;