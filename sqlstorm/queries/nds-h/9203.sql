
WITH Supplier_Stats AS (
    SELECT 
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name, n.n_name
),
Customer_Order_Stats AS (
    SELECT 
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
    GROUP BY 
        c.c_name, o.o_orderkey, o.o_orderdate
),
Top_Suppliers AS (
    SELECT 
        s.s_name,
        s.nation_name,
        total_cost,
        ROW_NUMBER() OVER (ORDER BY total_cost DESC) AS rank
    FROM 
        Supplier_Stats s
),
Top_Customers AS (
    SELECT 
        c.c_name,
        SUM(total_revenue) AS total_revenue,
        ROW_NUMBER() OVER (ORDER BY SUM(total_revenue) DESC) AS rank
    FROM 
        Customer_Order_Stats c
    GROUP BY 
        c.c_name
)
SELECT 
    t_s.s_name AS supplier_name,
    t_s.nation_name AS supplier_nation,
    t_c.c_name AS customer_name,
    t_c.total_revenue,
    t_s.total_cost
FROM 
    Top_Suppliers t_s
JOIN 
    Top_Customers t_c ON t_s.rank = t_c.rank
WHERE 
    t_s.rank <= 10 AND t_c.rank <= 10
ORDER BY 
    t_s.total_cost DESC, t_c.total_revenue DESC;
