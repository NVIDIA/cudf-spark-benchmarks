
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value,
        ROW_NUMBER() OVER (ORDER BY SUM(ps.ps_availqty) DESC) AS rank
    FROM 
        supplier AS s
    JOIN 
        partsupp AS ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value,
        COUNT(l.l_orderkey) AS item_count
    FROM 
        orders AS o
    JOIN 
        lineitem AS l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_totalprice
),
NationSupplier AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        s.s_suppkey,
        s.s_name
    FROM 
        nation AS n
    LEFT JOIN 
        supplier AS s ON n.n_nationkey = s.s_nationkey
)
SELECT 
    ns.n_name,
    COALESCE(SUM(os.order_value), 0) AS total_order_value,
    COUNT(DISTINCT os.o_orderkey) AS total_orders,
    COUNT(DISTINCT ss.s_suppkey) AS total_suppliers,
    MAX(ss.total_value) AS max_supplier_value
FROM 
    NationSupplier ns
LEFT JOIN 
    OrderDetails os ON ns.s_suppkey = os.o_orderkey
LEFT JOIN 
    SupplierStats ss ON ns.s_suppkey = ss.s_suppkey
GROUP BY 
    ns.n_name
HAVING 
    COUNT(DISTINCT os.o_orderkey) > 5
ORDER BY 
    total_order_value DESC;
