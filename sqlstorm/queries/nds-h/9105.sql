WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_regionkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'
    GROUP BY 
        c.c_custkey, c.c_name
),
HighSpenders AS (
    SELECT 
        cust.c_custkey,
        cust.c_name,
        cust.total_spent,
        COUNT(o.o_orderkey) as order_count
    FROM 
        CustomerOrders cust
    JOIN 
        orders o ON cust.c_custkey = o.o_custkey
    GROUP BY 
        cust.c_custkey, cust.c_name, cust.total_spent
    HAVING 
        cust.total_spent > 1000
)
SELECT 
    r.r_name AS region_name, 
    count(DISTINCT h.c_custkey) AS high_spending_cust_count, 
    SUM(s.total_supply_cost) AS total_supply_cost_in_region,
    AVG(h.order_count) as avg_orders_per_customer
FROM 
    RankedSuppliers s
JOIN 
    nation n ON s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_retailprice < 50))
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    HighSpenders h ON n.n_nationkey = h.c_custkey
GROUP BY 
    r.r_regionkey, r.r_name
ORDER BY 
    total_supply_cost_in_region DESC;