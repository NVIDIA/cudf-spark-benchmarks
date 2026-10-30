
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
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
SupplierPart AS (
    SELECT 
        s.s_suppkey,
        p.p_partkey,
        p.p_name,
        ps.ps_availqty
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ps.ps_availqty > 0
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 100000
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.total_revenue,
    s.p_name,
    h.c_name AS high_value_customer,
    COALESCE(s.p_name, 'No Supplier') AS part_name_supplier
FROM 
    RankedOrders r
LEFT JOIN 
    SupplierPart s ON r.o_orderkey = s.p_partkey
LEFT JOIN 
    HighValueCustomers h ON r.o_orderkey = h.c_custkey
WHERE 
    r.order_rank = 1 
    AND (h.total_spent IS NOT NULL OR s.p_partkey IS NOT NULL)
ORDER BY 
    total_revenue DESC,
    r.o_orderdate;
