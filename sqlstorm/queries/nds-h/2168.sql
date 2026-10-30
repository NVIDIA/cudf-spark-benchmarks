WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_regionkey
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(o.o_orderkey) AS order_count,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
PartSales AS (
    SELECT 
        p.p_partkey,
        p.p_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    cs.c_name,
    cs.total_order_value,
    COALESCE(RS.total_cost, 0) AS supplier_cost,
    ps.total_sales,
    ps.order_count AS part_order_count,
    CASE 
        WHEN cs.last_order_date IS NULL THEN 'No Orders'
        ELSE 'Has Orders'
    END AS order_status
FROM 
    CustomerOrderSummary cs
LEFT JOIN 
    RankedSuppliers RS ON cs.c_custkey = RS.s_suppkey
LEFT JOIN 
    PartSales ps ON cs.c_custkey = ps.p_partkey
WHERE 
    (cs.total_order_value > 10000 OR ps.total_sales > 5000)
    AND (RS.rnk IS NULL OR RS.rnk <= 3)
ORDER BY 
    cs.total_order_value DESC, ps.total_sales DESC;
