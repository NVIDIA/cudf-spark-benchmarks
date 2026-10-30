WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), NationDetails AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name,
        r.r_comment
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
), CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_nationkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
)
SELECT 
    nd.n_name AS nation_name,
    nd.region_name,
    COUNT(DISTINCT cs.c_custkey) AS customer_count,
    SUM(rs.total_supply_cost) AS total_supply_cost,
    MAX(cs.order_count) AS max_orders_per_customer
FROM 
    NationDetails nd
LEFT JOIN 
    CustomerDetails cs ON nd.n_nationkey = cs.c_nationkey
LEFT JOIN 
    RankedSuppliers rs ON nd.n_nationkey = rs.s_nationkey
WHERE 
    rs.rank <= 3
GROUP BY 
    nd.n_name, nd.region_name
ORDER BY 
    total_supply_cost DESC, customer_count DESC;
