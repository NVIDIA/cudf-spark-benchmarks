
WITH Ranked_Suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank_per_nation
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey = n.n_nationkey)
),
High_Value_Parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
Customer_Orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COUNT(o.o_orderkey) > 5
)
SELECT 
    r.r_name,
    p.p_name,
    sv.s_name AS top_supplier,
    SUM(l.l_discount * l.l_extendedprice) AS discounted_sale
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier sv ON ps.ps_suppkey = sv.s_suppkey
JOIN 
    part p ON l.l_partkey = p.p_partkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    c.c_name IN (SELECT c_name FROM Customer_Orders) 
    AND p.p_partkey IN (SELECT p_partkey FROM High_Value_Parts)
    AND sv.s_suppkey IN (SELECT s_suppkey FROM Ranked_Suppliers WHERE rank_per_nation = 1)
GROUP BY 
    r.r_name, p.p_name, sv.s_name
ORDER BY 
    r.r_name, discounted_sale DESC;
