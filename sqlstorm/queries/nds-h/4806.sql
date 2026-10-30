
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' 
        AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
TopRevenueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_orderstatus,
        ro.total_revenue
    FROM 
        RankedOrders ro
    JOIN 
        orders o ON ro.o_orderkey = o.o_orderkey
    WHERE 
        ro.order_rank <= 10
),
SupplierDetails AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        SUM(ps.ps_availqty) AS total_available_qty
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
)
SELECT 
    t.o_orderkey,
    t.o_orderdate,
    CASE 
        WHEN t.o_orderstatus = 'O' THEN 'Open'
        ELSE 'Closed'
    END AS order_status_label,
    COALESCE(sd.total_available_qty, 0) AS available_quantity,
    CONCAT('Order ', t.o_orderkey, ' has ', 
           CAST(t.total_revenue AS STRING) || ' in revenue and ' || 
           COALESCE(sd.total_available_qty, 0) || ' available from suppliers.') AS order_summary
FROM 
    TopRevenueOrders t
LEFT JOIN 
    SupplierDetails sd ON sd.ps_partkey IN (SELECT p.p_partkey 
                                              FROM part p 
                                              WHERE p.p_name LIKE '%widget%')
ORDER BY 
    t.total_revenue DESC;
