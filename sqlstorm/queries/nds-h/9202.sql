
WITH SupplierOrderDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
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
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
        AND o.o_orderstatus = 'F'
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
), OrderedSupplierRevenue AS (
    SELECT 
        s.*,
        RANK() OVER (PARTITION BY nation_name ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        SupplierOrderDetails s
)
SELECT 
    national.nation_name,
    s.s_name,
    s.total_orders,
    s.total_revenue
FROM 
    OrderedSupplierRevenue s
JOIN 
    (SELECT DISTINCT n.n_name AS nation_name FROM nation n) national ON s.nation_name = national.nation_name
WHERE 
    s.revenue_rank <= 5
ORDER BY 
    national.nation_name,
    s.total_revenue DESC;
