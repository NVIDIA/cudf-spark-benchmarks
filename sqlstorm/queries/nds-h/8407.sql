WITH SupplierOrderData AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
RankedSuppliers AS (
    SELECT 
        supplier_data.s_suppkey,
        supplier_data.s_name,
        supplier_data.nation_name,
        supplier_data.total_revenue,
        supplier_data.order_count,
        RANK() OVER (PARTITION BY supplier_data.nation_name ORDER BY supplier_data.total_revenue DESC) AS revenue_rank
    FROM 
        SupplierOrderData supplier_data
)
SELECT 
    r.s_suppkey,
    r.s_name,
    r.nation_name,
    r.total_revenue,
    r.order_count,
    r.revenue_rank
FROM 
    RankedSuppliers r
WHERE 
    r.revenue_rank <= 10
ORDER BY 
    r.nation_name, r.total_revenue DESC;