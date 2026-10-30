WITH Regional_Suppliers AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        AVG(s.s_acctbal) AS average_account_balance
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        n.n_name, r.r_name, s.s_suppkey
),
Customer_Orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS orders_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
High_Value_Customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
)
SELECT 
    r.nation_name,
    r.region_name,
    r.total_available_qty,
    r.total_supply_cost,
    r.average_account_balance,
    c.c_custkey,
    c.c_name,
    c.orders_count,
    c.total_spent,
    CASE 
        WHEN c.c_custkey IS NOT NULL THEN 'Valued Customer'
        ELSE 'Non-Valued Customer'
    END AS customer_type
FROM 
    Regional_Suppliers r
FULL OUTER JOIN 
    Customer_Orders c ON r.s_suppkey = c.c_custkey
WHERE 
    (r.total_available_qty IS NULL OR r.total_available_qty > 100)
    AND (r.total_supply_cost IS NOT NULL AND r.total_supply_cost < 5000)
ORDER BY 
    r.region_name, c.total_spent DESC NULLS LAST;
