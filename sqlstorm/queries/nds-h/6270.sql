WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        n.n_name AS nation_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, n.n_regionkey
), HighSupplySuppliers AS (
    SELECT 
        rs.s_suppkey, 
        rs.s_name, 
        rs.nation_name, 
        rs.total_supplycost
    FROM 
        RankedSuppliers rs 
    WHERE 
        rs.rank <= 5
), CustomerOrderStats AS (
    SELECT 
        c.c_custkey, 
        COUNT(o.o_orderkey) AS total_orders, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    s.s_name AS supplier_name, 
    s.nation_name, 
    c.c_custkey AS customer_key, 
    c.total_orders, 
    c.total_spent
FROM 
    HighSupplySuppliers s
JOIN 
    CustomerOrderStats c ON s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_type LIKE 'TYPE%') LIMIT 1)
WHERE 
    c.total_spent > 5000
ORDER BY 
    s.total_supplycost DESC, c.total_spent DESC;
