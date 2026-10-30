WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_within_nation
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopSupplierPerNation AS (
    SELECT 
        rs.nation_name,
        rs.s_name,
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rank_within_nation = 1
)
SELECT 
    cos.c_name AS customer_name,
    cos.total_orders,
    cos.total_spent,
    cos.avg_order_value,
    ts.nation_name,
    ts.s_name AS top_supplier,
    ts.total_supply_cost
FROM 
    CustomerOrderStats cos
JOIN 
    TopSupplierPerNation ts ON cos.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey IN 
        (SELECT l.l_orderkey 
         FROM lineitem l 
         WHERE l.l_partkey IN 
             (SELECT p.p_partkey 
              FROM part p 
              WHERE p.p_retailprice > 100.00) 
         GROUP BY l.l_orderkey 
         HAVING COUNT(*) > 5 LIMIT 1)) 
    ORDER BY 
        cos.total_spent DESC, cos.total_orders DESC;
