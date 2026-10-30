
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ps.ps_supplycost,
        (p.p_retailprice - ps.ps_supplycost) AS profit_margin
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        ps.ps_availqty > 0
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        COALESCE(SUM(li.l_extendedprice * (1 - li.l_discount)), 0) AS total_lineitem_value
    FROM 
        orders o
    LEFT JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE 
        o.o_orderdate < DATE '1998-10-01' - INTERVAL '30 days'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    r.r_name AS region,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(p.p_retailprice) AS total_part_retail_value,
    AVG(co.avg_order_value) AS average_customer_order_value,
    ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY COUNT(DISTINCT s.s_suppkey) DESC) AS region_rank
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    HighValueParts p ON p.p_brand = s.s_name
LEFT JOIN 
    CustomerOrders co ON co.c_custkey = s.s_suppkey
LEFT JOIN 
    FilteredOrders fo ON fo.o_orderkey = co.total_orders
WHERE 
    p.profit_margin IS NOT NULL
    AND (s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL) OR s.s_name IS NULL)
GROUP BY 
    r.r_name, r.r_regionkey
ORDER BY 
    total_part_retail_value DESC
LIMIT 10;
