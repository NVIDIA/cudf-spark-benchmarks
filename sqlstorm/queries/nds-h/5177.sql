
WITH TotalSales AS (
    SELECT 
        p.p_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY 
        p.p_partkey
),
SupplierSales AS (
    SELECT 
        s.s_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS supplier_revenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY 
        s.s_suppkey
),
CustomerSales AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS customer_expenditure
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY 
        c.c_custkey
),
TopSellingParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ts.total_revenue
    FROM 
        TotalSales ts
    JOIN 
        part p ON ts.p_partkey = p.p_partkey
    ORDER BY 
        ts.total_revenue DESC
    LIMIT 10
)
SELECT 
    ts.p_name,
    ts.total_revenue,
    ss.supplier_revenue,
    cs.customer_expenditure
FROM 
    TopSellingParts ts
JOIN 
    SupplierSales ss ON ts.p_partkey = ss.s_suppkey
JOIN 
    CustomerSales cs ON cs.customer_expenditure > 1000
ORDER BY 
    ts.total_revenue DESC, ss.supplier_revenue DESC, cs.customer_expenditure DESC;
