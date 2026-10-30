
WITH OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_name, c.c_nationkey
),
SupplierDetail AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopCustomers AS (
    SELECT 
        os.o_orderkey,
        os.c_name,
        os.total_value
    FROM 
        OrderSummary os
    WHERE 
        os.rank <= 5
)
SELECT 
    tc.o_orderkey,
    tc.c_name,
    tc.total_value,
    COALESCE(sd.total_supply_cost, 0) AS total_supply_cost,
    CASE 
        WHEN tc.total_value > 10000 THEN 'High'
        WHEN tc.total_value BETWEEN 5000 AND 10000 THEN 'Medium'
        ELSE 'Low'
    END AS value_category,
    CASE 
        WHEN sd.total_supply_cost IS NULL THEN 'No Supplier Data'
        ELSE 'Supplier Data Available'
    END AS supplier_info
FROM 
    TopCustomers tc
LEFT JOIN 
    SupplierDetail sd ON tc.o_orderkey = sd.s_suppkey
ORDER BY 
    tc.total_value DESC;
