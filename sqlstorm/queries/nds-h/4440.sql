WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 1000
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(l.l_orderkey) AS line_count,
        AVG(l.l_quantity) AS avg_quantity
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL
    GROUP BY 
        c.c_custkey
)

SELECT 
    r.r_name,
    COALESCE(cs.order_count, 0) AS customer_order_count,
    COALESCE(cs.total_spent, 0) AS total_spent,
    COUNT(DISTINCT rs.s_suppkey) AS supplier_count,
    AVG(os.total_sales) AS avg_order_sales,
    MAX(os.avg_quantity) AS max_avg_quantity
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    RankedSuppliers rs ON n.n_nationkey = rs.s_suppkey
LEFT JOIN 
    CustomerOrders cs ON n.n_nationkey = cs.c_custkey
LEFT JOIN 
    OrderStats os ON os.o_orderkey = cs.order_count
WHERE 
    r.r_comment IS NOT NULL
GROUP BY 
    r.r_name, cs.order_count, cs.total_spent
ORDER BY 
    r.r_name;