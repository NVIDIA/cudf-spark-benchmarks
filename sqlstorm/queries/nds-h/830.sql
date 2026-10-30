WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        o.o_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        orders o
    GROUP BY 
        o.o_custkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_nationkey,
        co.order_count,
        co.total_spent
    FROM 
        customer c
    JOIN 
        CustomerOrders co ON c.c_custkey = co.o_custkey
    WHERE 
        co.total_spent > 10000
),
PartSupplier AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        ps.ps_availqty,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT hvc.c_custkey) AS high_value_cust_count,
    AVG(ss.avg_supply_cost) AS avg_supply_cost,
    MAX(ps.rank) AS max_rank
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    HighValueCustomers hvc ON n.n_nationkey = hvc.c_nationkey
LEFT JOIN 
    SupplierStats ss ON ss.total_available > 100
LEFT JOIN 
    PartSupplier ps ON ps.ps_availqty > 50
WHERE 
    r.r_name LIKE 'Asia%'
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT hvc.c_custkey) > 5
ORDER BY 
    high_value_cust_count DESC;
