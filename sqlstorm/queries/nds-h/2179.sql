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
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_linenumber) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(od.total_revenue) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        OrderDetails od ON o.o_orderkey = od.o_orderkey
    WHERE 
        c.c_acctbal IS NOT NULL AND c.c_acctbal > 0
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(od.total_revenue) > 10000
),
SupplierPerformance AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        ss.total_available,
        ss.avg_supply_cost,
        tc.total_spent
    FROM 
        SupplierStats ss
    LEFT JOIN 
        TopCustomers tc ON ss.s_suppkey = tc.c_custkey
)
SELECT 
    sp.s_name,
    COALESCE(sp.total_available, 0) AS total_available,
    COALESCE(sp.avg_supply_cost, 0) AS avg_supply_cost,
    COALESCE(sp.total_spent, 0) AS total_spent,
    CASE 
        WHEN sp.total_spent IS NULL THEN 'No Sales'
        WHEN sp.total_spent > 0 THEN 'Active Customer'
        ELSE 'Inactive Customer'
    END AS customer_status
FROM 
    SupplierPerformance sp
ORDER BY 
    total_spent DESC NULLS LAST;
