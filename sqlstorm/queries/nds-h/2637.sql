WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        MAX(s.s_acctbal) AS max_account_balance
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueSuppliers AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        ss.total_available_qty,
        ss.total_supply_value,
        ss.max_account_balance
    FROM 
        SupplierSummary ss
    WHERE 
        ss.total_supply_value > (SELECT AVG(total_supply_value) FROM SupplierSummary)
),
OrderDetails AS (
    SELECT 
        li.l_orderkey,
        li.l_partkey,
        li.l_suppkey,
        li.l_quantity,
        li.l_extendedprice,
        li.l_discount,
        li.l_tax,
        li.l_returnflag,
        li.l_shipdate
    FROM 
        lineitem li
    WHERE 
        li.l_shipdate >= DATE '1997-01-01' AND li.l_shipdate < DATE '1998-01-01'
),
FinalReport AS (
    SELECT 
        cu.c_custkey,
        cu.c_name,
        COALESCE(hu.total_available_qty, 0) AS available_qty,
        COALESCE(hu.total_supply_value, 0) AS supply_value,
        COALESCE(od.order_count, 0) AS order_count,
        COALESCE(od.total_spent, 0) AS total_spent
    FROM 
        CustomerOrders od
    FULL OUTER JOIN 
        HighValueSuppliers hu ON od.c_custkey = hu.s_suppkey
    JOIN 
        customer cu ON od.c_custkey = cu.c_custkey
)
SELECT 
    fr.c_custkey,
    fr.c_name,
    fr.available_qty,
    fr.supply_value,
    fr.order_count,
    fr.total_spent,
    (CASE 
        WHEN fr.total_spent > 1000 THEN 'High Value Customer'
        WHEN fr.total_spent BETWEEN 500 AND 1000 THEN 'Mid Value Customer'
        ELSE 'Low Value Customer'
    END) AS customer_value_segment
FROM 
    FinalReport fr
WHERE 
    fr.total_spent IS NOT NULL
ORDER BY 
    fr.total_spent DESC;