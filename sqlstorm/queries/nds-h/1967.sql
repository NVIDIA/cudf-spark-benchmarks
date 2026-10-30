
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    p.p_name, 
    COUNT(DISTINCT l.l_orderkey) AS total_orders,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS net_revenue,
    COUNT(DISTINCT o.o_orderkey) AS completed_orders,
    MAX(CASE WHEN o.o_orderstatus = 'F' THEN o.o_totalprice END) AS max_filled_order,
    AVG(CASE WHEN o.o_orderstatus = 'P' THEN o.o_totalprice END) AS avg_pending_order_value,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    rd.total_spent AS customer_total_spent,
    CASE 
        WHEN rd.order_count > 0 THEN 'Active' 
        ELSE 'Inactive' 
    END AS customer_status
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    SupplierDetails s ON l.l_suppkey = s.s_suppkey
LEFT JOIN 
    CustomerOrders rd ON o.o_custkey = rd.c_custkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_retailprice > 100
GROUP BY 
    p.p_name, s.s_name, c.c_name, rd.total_spent, rd.order_count
HAVING 
    SUM(l.l_quantity) > 50 
    AND MAX(l.l_shipdate) > DATE '1998-10-01' - INTERVAL '30 days'
ORDER BY 
    total_orders DESC, net_revenue DESC;
