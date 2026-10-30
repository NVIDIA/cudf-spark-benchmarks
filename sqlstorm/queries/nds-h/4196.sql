WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        o.o_orderstatus, 
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_order
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
),
TopProducts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(l.l_quantity) AS total_quantity
    FROM 
        lineitem l
    JOIN 
        part p ON l.l_partkey = p.p_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(l.l_quantity) > 100
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        n.n_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > 500.00
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
    HAVING 
        SUM(ps.ps_availqty) > 100
)
SELECT 
    o.o_orderkey, 
    o.o_orderdate, 
    o.o_totalprice, 
    tp.p_name, 
    sd.s_name, 
    sd.total_cost, 
    CASE 
        WHEN o.o_orderstatus = 'F' THEN 'Finalized'
        WHEN o.o_orderstatus = 'P' THEN 'Pending'
        ELSE 'Unknown'
    END AS order_status_desc
FROM 
    RankedOrders o
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    TopProducts tp ON l.l_partkey = tp.p_partkey
LEFT JOIN 
    SupplierDetails sd ON l.l_suppkey = sd.s_suppkey
WHERE 
    o.rank_order <= 10
ORDER BY 
    o.o_orderdate DESC, o.o_totalprice ASC, tp.total_quantity DESC;