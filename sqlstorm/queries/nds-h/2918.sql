WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COUNT(ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost) AS total_supplycost,
        ROW_NUMBER() OVER (ORDER BY SUM(ps.ps_supplycost) DESC) AS rank_supplier
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_item_value,
        ROW_NUMBER() OVER (ORDER BY o.o_totalprice DESC) AS rank_order
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice
),
CustomerRanking AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        RANK() OVER (ORDER BY c.c_acctbal DESC) AS customer_rank
    FROM 
        customer c
)
SELECT 
    coalesce(n.n_name, 'Unknown') AS nation,
    SUM(o.o_totalprice) AS total_order_value,
    AVG(s.s_acctbal) AS avg_supplier_acctbal,
    COUNT(DISTINCT s.s_suppkey) AS unique_suppliers,
    MAX(hi.total_line_item_value) AS max_order_value,
    COUNT(DISTINCT cu.c_custkey) AS unique_customers
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    CustomerRanking cu ON cu.c_custkey = o.o_custkey
LEFT JOIN 
    HighValueOrders hi ON hi.o_orderkey = o.o_orderkey
GROUP BY 
    n.n_name
HAVING 
    SUM(o.o_totalprice) > 10000 AND 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    total_order_value DESC, avg_supplier_acctbal ASC;
