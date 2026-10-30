WITH  CTE_SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        c.c_name AS customer_name,
        ROW_NUMBER() OVER (ORDER BY SUM(CASE WHEN o.o_orderstatus = 'O' THEN l.l_extendedprice ELSE 0 END) DESC) AS rank
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    LEFT JOIN 
        customer c ON o.o_custkey = c.c_custkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, c.c_name
),
TotalByRegion AS (
    SELECT 
        n.n_regionkey,
        r.r_name,
        COUNT(DISTINCT c.c_custkey) AS total_customers,
        SUM(o.o_totalprice) AS total_revenue
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_regionkey, r.r_name
)
SELECT 
    ts.s_suppkey,
    ts.s_name,
    ts.s_acctbal,
    ts.customer_name,
    tbr.total_revenue,
    tbr.total_customers
FROM 
    TopSuppliers ts
JOIN 
    TotalByRegion tbr ON ts.s_suppkey IN (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        WHERE ps.ps_partkey IN (
            SELECT p.p_partkey
            FROM part p
            WHERE p.p_container LIKE '%BOX%'
        )
    )
WHERE 
    ts.rank <= 5
ORDER BY 
    tbr.total_revenue DESC, ts.s_name;
