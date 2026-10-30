
WITH PartSupply AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
),
SupplierNation AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(s.s_acctbal) AS total_acctbal
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
CustomerOrder AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    ps.p_partkey,
    ps.p_name,
    ps.p_brand,
    ps.total_avail_qty,
    ps.total_supply_cost,
    sn.nation_name,
    cn.c_name AS customer_name,
    cn.total_orders,
    cn.total_spent
FROM 
    PartSupply ps
JOIN 
    SupplierNation sn ON ps.p_partkey = sn.s_suppkey
LEFT JOIN 
    CustomerOrder cn ON cn.total_orders > 0
WHERE 
    ps.total_supply_cost > 1000
ORDER BY 
    ps.total_avail_qty DESC, cn.total_spent DESC
LIMIT 50;
