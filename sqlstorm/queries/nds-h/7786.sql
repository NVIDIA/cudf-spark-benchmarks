WITH SupplierTotals AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS item_count,
        o.o_orderdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_orderdate
),
CustomerSpending AS (
    SELECT 
        c.c_custkey,
        SUM(os.total_revenue) AS total_spent,
        COUNT(os.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        OrderSummary os ON c.c_custkey = os.o_custkey
    GROUP BY 
        c.c_custkey
),
TopSuppliers AS (
    SELECT 
        st.s_suppkey,
        st.total_cost,
        st.part_count,
        RANK() OVER (ORDER BY st.total_cost DESC) as rank
    FROM 
        SupplierTotals st
    WHERE 
        st.part_count > 5
),
TopCustomers AS (
    SELECT 
        cs.c_custkey,
        cs.total_spent,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_spent DESC) as rank
    FROM 
        CustomerSpending cs
    WHERE 
        cs.order_count > 3
)
SELECT 
    tc.c_custkey,
    ts.s_suppkey,
    ts.total_cost,
    tc.total_spent
FROM 
    TopCustomers tc
JOIN 
    TopSuppliers ts ON ts.rank = 1
WHERE 
    ts.part_count = (SELECT MAX(part_count) FROM TopSuppliers)
ORDER BY
    tc.total_spent DESC, ts.total_cost DESC
LIMIT 10;