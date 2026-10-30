WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        COUNT(ps.ps_partkey) AS parts_supplied,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
FinalReport AS (
    SELECT 
        rc.o_orderkey,
        rc.total_revenue,
        tc.c_name AS top_customer,
        tc.total_spent,
        ss.s_name AS top_supplier,
        ss.parts_supplied,
        ss.total_supply_cost
    FROM 
        RankedOrders rc
    JOIN 
        TopCustomers tc ON rc.o_orderkey = tc.c_custkey
    JOIN 
        SupplierSummary ss ON tc.total_spent = ss.total_supply_cost
    WHERE 
        rc.revenue_rank <= 10
)
SELECT 
    FR.*,
    CONCAT('Order ', FR.o_orderkey, ' has revenue of ', FR.total_revenue, ', top customer ', FR.top_customer, ' spent ', FR.total_spent, ', and top supplier ', FR.top_supplier, ' supplied ', FR.parts_supplied, ' parts with total cost ', FR.total_supply_cost) AS benchmark_message
FROM 
    FinalReport FR;