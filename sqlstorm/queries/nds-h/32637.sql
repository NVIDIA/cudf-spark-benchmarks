WITH  RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    ORDER BY 
        total_cost DESC
    LIMIT 10
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE 
        li.l_shipdate >= '1997-01-01' AND li.l_shipdate < '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' 
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
),
SupplierPerformance AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        COALESCE(os.total_revenue, 0) AS order_revenue,
        COALESCE(tc.total_spent, 0) AS customer_spending,
        RANK() OVER (ORDER BY COALESCE(os.total_revenue, 0) + COALESCE(tc.total_spent, 0) DESC) AS supplier_rank
    FROM 
        RankedSuppliers rs
    LEFT JOIN 
        OrderSummary os ON rs.s_suppkey = os.o_orderkey 
    LEFT JOIN 
        TopCustomers tc ON rs.s_suppkey = tc.c_custkey 
)
SELECT 
    sp.supplier_rank,
    sp.s_name,
    sp.order_revenue,
    sp.customer_spending,
    (sp.order_revenue + sp.customer_spending) AS total_performance
FROM 
    SupplierPerformance sp
ORDER BY 
    sp.supplier_rank;