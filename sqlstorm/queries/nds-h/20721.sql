
WITH  ranked_line_items AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        l.l_linenumber,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_tax,
        l.l_returnflag,
        l.l_linestatus,
        l.l_shipdate,
        l.l_commitdate,
        l.l_receiptdate,
        l.l_shipinstruct,
        l.l_shipmode,
        l.l_comment,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS rank
    FROM 
        lineitem l
    WHERE 
        l.l_quantity < 1000
),
supplier_details AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total,
        CASE 
            WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000 THEN 'High Value'
            ELSE 'Regular'
        END AS order_type
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    os.o_orderkey,
    r.n_name AS nation_name,
    ss.s_name AS supplier_name,
    os.order_total,
    li.rank,
    CASE 
        WHEN os.order_type = 'High Value' THEN 'VIP'
        ELSE 'Standard'
    END AS customer_priority,
    COALESCE(supply_info.total_supply_value, 0) AS total_supplier_value,
    CASE 
        WHEN li.l_returnflag = 'R' THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status
FROM 
    order_summary os
JOIN 
    ranked_line_items li ON os.o_orderkey = li.l_orderkey
JOIN 
    supplier_details ss ON li.l_suppkey = ss.s_suppkey
JOIN 
    customer c ON os.o_orderkey = c.c_custkey
JOIN 
    nation r ON c.c_nationkey = r.n_nationkey
LEFT JOIN (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost) AS total_supply_value
    FROM 
        partsupp ps
    WHERE 
        ps.ps_availqty IS NOT NULL
    GROUP BY 
        ps.ps_suppkey
) AS supply_info ON ss.s_suppkey = supply_info.ps_suppkey
WHERE 
    os.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
ORDER BY 
    os.order_total DESC, 
    c.c_name ASC;
