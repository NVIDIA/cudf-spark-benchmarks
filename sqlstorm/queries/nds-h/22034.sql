
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > (SELECT AVG(o_totalprice) FROM orders)
),
AdjustedLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        (l.l_extendedprice * (1 - l.l_discount)) AS adjusted_price,
        CASE 
            WHEN l.l_returnflag = 'R' THEN 'Returned'
            WHEN l.l_discount > 0.2 THEN 'Discounted'
            ELSE 'Standard'
        END AS price_category
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate > '1997-01-01'
),
SupplierPartCounts AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    p.p_name AS part_name,
    l.total_spent,
    spc.supplier_count,
    SUM(CASE 
            WHEN a.price_category = 'Discounted' THEN a.adjusted_price
            ELSE 0 
        END) AS total_discounted_sales,
    COUNT(CASE 
            WHEN a.l_quantity > 100 THEN 1 
            END) AS high_quantity_items
FROM 
    RankedSuppliers rs
LEFT JOIN 
    supplier s ON rs.s_suppkey = s.s_suppkey
JOIN 
    SupplierPartCounts spc ON rs.s_suppkey = spc.ps_partkey
JOIN 
    part p ON spc.ps_partkey = p.p_partkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    HighValueCustomers l ON l.c_custkey = s.s_nationkey
JOIN 
    AdjustedLineItems a ON a.l_partkey = p.p_partkey
GROUP BY 
    r.r_name, n.n_name, p.p_name, l.total_spent, spc.supplier_count
HAVING 
    SUM(a.adjusted_price) IS NOT NULL
ORDER BY 
    total_discounted_sales DESC;
