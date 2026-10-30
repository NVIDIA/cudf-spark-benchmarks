WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
),
supplier_stats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 1000
    GROUP BY 
        c.c_custkey, c.c_name
),
lineitem_summary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate <= DATE '1997-12-31'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.o_orderkey AS Order_ID,
    r.o_orderdate AS Order_Date,
    r.o_totalprice AS Total_Price,
    r.o_orderstatus AS Order_Status,
    cs.c_name AS Customer_Name,
    ss.s_name AS Supplier_Name,
    ls.revenue AS Total_Revenue,
    ss.total_avail_qty AS Total_Available_Quantity,
    cs.total_spent AS Total_Spent_By_Customer
FROM 
    ranked_orders r
LEFT JOIN 
    customer_orders cs ON r.o_orderkey = cs.order_count
LEFT JOIN 
    lineitem_summary ls ON r.o_orderkey = ls.l_orderkey
LEFT JOIN 
    supplier_stats ss ON ss.total_avail_qty = ls.unique_parts
WHERE 
    r.order_rank <= 10
ORDER BY 
    r.o_orderdate DESC;