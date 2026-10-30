
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        o.o_orderkey,
        o.o_totalprice,
        DENSE_RANK() OVER (ORDER BY o.o_orderdate ASC) AS order_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer) 
)

SELECT 
    co.c_custkey, 
    co.o_orderkey, 
    co.o_totalprice,
    rs.s_suppkey, 
    rs.s_name, 
    rs.total_supply_cost
FROM 
    CustomerOrders co
LEFT OUTER JOIN 
    RankedSuppliers rs ON MOD(co.o_orderkey, 10) = rs.rnk
WHERE 
    co.order_rank <= 10
    AND (rs.total_supply_cost IS NOT NULL OR co.o_totalprice > 1000)
ORDER BY 
    co.c_custkey, 
    co.o_orderkey;
