WITH RegionSummary AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(CASE WHEN s.s_acctbal > 10000 THEN 1 ELSE 0 END) AS high_value_suppliers,
        SUM(CASE WHEN p.p_size > 20 THEN p.p_retailprice ELSE 0 END) AS total_high_size_price
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        r.r_name
),
CustomerOrders AS (
    SELECT 
        c.c_name AS customer_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_name
)
SELECT 
    rs.region_name,
    rs.nation_count,
    rs.high_value_suppliers,
    rs.total_high_size_price,
    co.customer_name,
    co.order_count,
    co.total_spent,
    co.avg_order_value
FROM 
    RegionSummary rs
JOIN 
    CustomerOrders co ON rs.nation_count > 5
ORDER BY 
    rs.region_name, co.total_spent DESC;
